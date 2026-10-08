<?php

namespace App\Http\Controllers;

use App\Models\API3Users;
use Illuminate\Http\Request;
use App\CustomClasses\CustomHeaderAuth;

class API3UsersController extends Controller
{
    public function login(Request $request)
    {

        $user=API3Users::where('username',$request->input('username'))
            ->where('password',$request->input('password'))->first();

        if($user)
        {
            return response(json_encode(array("success"=>"true","username"=>$user->username)), 200)
            ->header('Content-Type', 'application/json');
        }
        else
        {
            return response(json_encode(array("success"=>"false","cause"=>"Incorrect Username or Password")), 401)
            ->header('Content-Type', 'application/json');
        }

    }

    public function store(Request $request)
    {
        return API3Users::create(json_decode($request->getContent(), true));
    }

    public function show(Request $request,$id)
    {
        if($request->hasHeader('Authorization-Token') && $request->header('Authorization-Token')!="" )
        {
            $user = new CustomHeaderAuth($request->header('Authorization-Token'));
            $validuser = API3Users::where('username',$user->getUsername())->where('password',$user->getPassword())->count();

            if($validuser>0)
            {
                // Same bug as API1: any registered user's token is accepted, but the id in the
                // path is never checked against the authenticated user, so it returns whichever
                // user you ask for -- Broken Object Level Authorization (BOLA).
                return API3Users::find($id);
            }
            else
            {
                return response(json_encode(array("success"=>"false","cause"=>"usernameOrPasswordIncorrect")), 403)
                ->header('Content-Type', 'application/json');
            }

        }

        return response(json_encode(array("success"=>"false","cause"=>"authHeaderNotSet")), 403)
            ->header('Content-Type', 'application/json');
    }

}
